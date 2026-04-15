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
                raise e
        return {'statusCode': 200, 'body': 'SQS Batch processed'}

    # 2. EventBridge / Direct Mode (STOP Action)
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

    # Enqueue valid payloads
    sqs = boto3.client('sqs')
    queue_url = os.environ['SQS_QUEUE_URL']

    payload = {
        "source": "github",
        "github_event": event_type,
        "ref": ref,
        "repository": repo_name,
        "body_str": body_str
    }

    try:
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(payload)
        )
        return {
            'statusCode': 202,
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
    
    if event_type == 'push':
        ref = (body_obj.get('ref') or '')
        repo_name = body_obj.get("repository", {}).get("name", "")
        if ref == 'refs/heads/develop':
            return True, 'push', ref, repo_name
    
    elif event_type == 'pull_request':
        action = body_obj.get('action')
        pr = body_obj.get('pull_request', {})
        merged = pr.get('merged', False)
        base_ref = pr.get('base', {}).get('ref', '')
        repo_name = body_obj.get("repository", {}).get("name", "")
        
        if action == 'closed' and merged and base_ref == 'develop':
            return True, 'pull_request', 'refs/heads/develop', repo_name

    return False, event_type, None, None

def process_main_logic(event, context):
    ec2 = boto3.client('ec2')
    rds = boto3.client('rds')

    bastion_id      = os.environ['BASTION_INSTANCE_ID']
    nat_id          = os.environ['NAT_INSTANCE_ID']
    backend_id      = os.environ['BACKEND_INSTANCE_ID']
    rds_identifier  = os.environ.get('RDS_IDENTIFIER', '')  # optional

    # --- STOP Action ---
    if str(event.get("action", "")).upper() == "STOP":
        print("ACTION: STOP. Stopping EC2 instances and RDS.")
        try:
            ec2.stop_instances(InstanceIds=[bastion_id, nat_id, backend_id])
            if rds_identifier:
                try:
                    rds.stop_db_instance(DBInstanceIdentifier=rds_identifier)
                    print(f"RDS {rds_identifier} stop initiated.")
                except Exception as e:
                    print(f"RDS stop skipped (may already be stopped): {e}")
            return {'statusCode': 200, 'body': json.dumps('Environment stopped.')}
        except Exception as e:
            print(f"Error stopping environment: {e}")
            return {'statusCode': 500, 'body': str(e)}

    # --- START Action (Strict Checks) ---
    if event.get("source") != "github":
        print("Ignored: not github source")
        return {'statusCode': 200, 'body': 'ignored'}
        
    gh_event = event.get("github_event")
    if gh_event not in ['push', 'pull_request']:
        print(f"Ignored: event type {gh_event}")
        return {'statusCode': 200, 'body': 'ignored'}

    if event.get("ref") != "refs/heads/develop":
        print(f"Ignored: ref is {event.get('ref')}")
        return {'statusCode': 200, 'body': 'ignored'}

    repo_name = (event.get("repository") or "").upper()
    
    if "BE" not in repo_name and "FE" not in repo_name:
        print(f"Ignored: repository name not matched (repo={repo_name})")
        return {'statusCode': 200, 'body': 'ignored: unknown repo'}

    print(f"ACTION: START. Starting infrastructure for repo: {repo_name}")
    try:
        # Always start Bastion, NAT, and Backend EC2 on any push
        ec2.start_instances(InstanceIds=[bastion_id, nat_id, backend_id])
        
        if rds_identifier:
            try:
                rds.start_db_instance(DBInstanceIdentifier=rds_identifier)
                print(f"RDS {rds_identifier} start initiated.")
            except Exception as e:
                print(f"RDS start skipped (may already be running): {e}")

    except Exception as e:
        print(f"Error starting environment: {e}")

    # CI/CD is handled by GitHub Actions — no Jenkins forwarding needed

    return {'statusCode': 200, 'body': json.dumps('Environment startup initiated.')}
