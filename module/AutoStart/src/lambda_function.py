import boto3
import os
import json
import urllib.request
import time
import base64

def lambda_handler(event, context):
    # --- LOGIC SEPARATION ---
    # 1. SQS Worker Mode (Processing from Queue)
    if 'Records' in event:
        print(f"Triggered by SQS. Batch size: {len(event['Records'])}")
        for record in event['Records']:
            try:
                payload = json.loads(record['body'])
                process_main_logic(payload, context)
            except Exception as e:
                print(f"Error processing SQS record: {e}")
                # Re-raise to let SQS handle retry/DLQ if necessary
                raise e
        return {'statusCode': 200, 'body': 'SQS Batch processed'}

    # 2. EventBridge / Direct Mode (STOP Action)
    # EventBridge sends {"action": "STOP"} directly
    if str(event.get('action', '')).upper() == 'STOP':
        print("Triggered by EventBridge (STOP action). Processing synchronously...")
        return process_main_logic(event, context)

    # 3. Webhook Producer Mode
    print("Triggered by Webhook. Validating GitHub event...")

    headers_in = event.get('headers') or {}
    headers_norm = {k.lower(): v for k, v in headers_in.items()}

    body_str = event.get('body') or '{}'
    if event.get('isBase64Encoded'):
        body_str = base64.b64decode(body_str).decode('utf-8', errors='replace')

    try:
        body_obj = json.loads(body_str)
    except Exception as e:
        print(f"Invalid JSON body. Ignoring. Error: {e}")
        return {'statusCode': 200, 'body': 'Ignored: invalid json'}

    # Strict Validation: Accept GitHub Push OR PR Merge to Develop
    is_valid, event_type, ref, repo_name = validate_github_event(headers_norm, body_obj)
    
    if not is_valid:
        print("Ignored: not a valid GitHub push or PR merge to develop")
        return {'statusCode': 200, 'body': 'Ignored: invalid event'}

    # ✅ Enqueue only valid payloads
    sqs = boto3.client('sqs')
    queue_url = os.environ['SQS_QUEUE_URL']

    # Normalize payload for worker
    payload = {
        "source": "github",
        "github_event": event_type, # 'push' or 'pull_request'
        "ref": ref,                 # 'refs/heads/develop'
        "repository": repo_name,
        "body_str": body_str        # Pass original body for Jenkins forwarding
    }

    try:
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(payload)
        )
        return {
            'statusCode': 202, # Accepted
            'body': json.dumps('Accepted. Queued for background processing.')
        }
    except Exception as e:
        print(f"Error sending to SQS: {e}")
        return {'statusCode': 500, 'body': str(e)}

def validate_github_event(headers_norm, body_obj):
    """
    Validates if the event is a Push to develop OR a PR Merged to develop.
    Returns: (is_valid, event_type, ref, repo_name)
    """
    event_type = headers_norm.get('x-github-event', '')
    
    # Case A: Push Event
    if event_type == 'push':
        ref = (body_obj.get('ref') or '')
        repo_name = body_obj.get("repository", {}).get("name", "")
        if ref == 'refs/heads/develop':
            return True, 'push', ref, repo_name
    
    # Case B: Pull Request Event (Merge)
    elif event_type == 'pull_request':
        action = body_obj.get('action')
        pr = body_obj.get('pull_request', {})
        merged = pr.get('merged', False)
        base_ref = pr.get('base', {}).get('ref', '')
        repo_name = body_obj.get("repository", {}).get("name", "")
        
        # Condition: Closed AND Merged AND Base is develop
        if action == 'closed' and merged and base_ref == 'develop':
            # Normalize ref to develop for consistency in downstream logic
            return True, 'pull_request', 'refs/heads/develop', repo_name

    return False, event_type, None, None

def process_main_logic(event, context):
    ec2 = boto3.client('ec2')
    ecs = boto3.client('ecs')

    bastion_id = os.environ['BASTION_INSTANCE_ID']
    nat_id = os.environ['NAT_INSTANCE_ID']
    
    # fe_instance_id = os.environ['FRONTEND_INSTANCE_ID']
    # be_instance_id = os.environ['BACKEND_INSTANCE_ID']
    fe_cluster = os.environ['FRONTEND_CLUSTER_NAME']
    fe_service = os.environ['FRONTEND_SERVICE_NAME']
    be_cluster = os.environ['BACKEND_CLUSTER_NAME']
    be_service = os.environ['BACKEND_SERVICE_NAME']

    # --- STOP Action ---
    if str(event.get("action", "")).upper() == "STOP":
        # all_instances = [bastion_id, nat_id, fe_instance_id, be_instance_id]
        # print(f"ACTION: STOP. Stopping all instances: {all_instances}")
        print("ACTION: STOP. Stopping EC2 instances and ECS services.")
        try:
            # ec2.stop_instances(InstanceIds=all_instances)
            ec2.stop_instances(InstanceIds=[bastion_id, nat_id])
            ecs.update_service(cluster=fe_cluster, service=fe_service, desiredCount=0)
            ecs.update_service(cluster=be_cluster, service=be_service, desiredCount=0)
            return {'statusCode': 200, 'body': json.dumps('Environment stopped.')}
        except Exception as e:
            print(f"Error stopping environment: {e}")
            return {'statusCode': 500, 'body': str(e)}

    # --- START Action (Strict Checks) ---
    # 1. Validation: Must be from GitHub source, push OR pull_request event
    if event.get("source") != "github":
        print("Ignored: not github source")
        return {'statusCode': 200, 'body': 'ignored'}
        
    gh_event = event.get("github_event")
    if gh_event not in ['push', 'pull_request']:
        print(f"Ignored: event type {gh_event}")
        return {'statusCode': 200, 'body': 'ignored'}

    # 2. Validation: Must be develop branch
    if event.get("ref") != "refs/heads/develop":
        print(f"Ignored: ref is {event.get('ref')}")
        return {'statusCode': 200, 'body': 'ignored'}

    repo_name = (event.get("repository") or "").upper()
    instances_to_start = [bastion_id, nat_id]
    
    start_fe = False
    start_be = False

    if "BE" in repo_name:
        # instances_to_start.append(be_instance_id)
        start_be = True
    elif "FE" in repo_name:
        # instances_to_start.append(fe_instance_id)
        start_fe = True
    else:
        # ✅ NO FALLBACK START ALL
        print(f"Ignored: repository name not matched (repo={repo_name})")
        return {'statusCode': 200, 'body': 'ignored: unknown repo'}

    # print(f"ACTION: START. Starting instances: {instances_to_start}")
    print(f"ACTION: START. Starting EC2 instances {instances_to_start} and relevant ECS services.")
    try:
        ec2.start_instances(InstanceIds=instances_to_start)
        if start_fe:
            ecs.update_service(cluster=fe_cluster, service=fe_service, desiredCount=1)
        if start_be:
            ecs.update_service(cluster=be_cluster, service=be_service, desiredCount=1)
    except Exception as e:
        print(f"Error starting environment: {e}")

    # Forward to Jenkins (if needed and supported by original payload)
    if bastion_id in instances_to_start:
         try:
            jenkins_url = "https://jenkins.fuec.site/github-webhook/"
            print(f"Forwarding trigger to Jenkins: {jenkins_url}")
            
            # Use the actual event type for Jenkins (push or pull_request)
            headers_out = {
                'Content-Type': 'application/json',
                'X-GitHub-Event': gh_event,
                'User-Agent': 'AWS-Lambda-AutoStart'
            }
            
            # Use original body string if available, else re-dump body object
            body_content = event.get('body_str') or json.dumps(event.get('body', {}))

            req = urllib.request.Request(
                jenkins_url,
                data=body_content.encode('utf-8'),
                headers=headers_out,
                method='POST'
            )
            
            # Fail Fast: If Jenkins is down, this raises URLError/HTTPError
            # The Exception will bubble up, causing Lambda to fail.
            # SQS will then retry this message after VisibilityTimeout (60s).
            with urllib.request.urlopen(req, timeout=10) as response:
                print(f"Jenkins Triggered Successfully: {response.status}")

         except Exception as e:
            print(f"Error forwarding to Jenkins: {e}")
            print("Raising exception to trigger SQS Retry...")
            raise e # CRITICAL: This ensures SQS keeps the message

    return {'statusCode': 200, 'body': json.dumps('Environment startup initiated.')}
