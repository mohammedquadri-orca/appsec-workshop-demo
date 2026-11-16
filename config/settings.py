"""Application settings – all credentials come from the environment.

Fixed: hardcoded credentials removed. NOTE: the old FAKE values are still in
git history, so Orca keeps reporting them (only_in_history). Real-world
talk track: ROTATE the credential first, then close the alert.
"""
import os

APP_NAME = "orca-appsec-demo"

AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
# Prefer the instance role / default credential chain; never hardcode keys.
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
JWT_SIGNING_KEY = os.environ.get("JWT_SIGNING_KEY")
