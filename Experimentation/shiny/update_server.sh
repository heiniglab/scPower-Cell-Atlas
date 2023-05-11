#!/bin/bash

REPO_URL="https://raw.githubusercontent.com"
REPO_OWNER="heiniglab"
REPO_NAME="scPower"
BRANCH_NAME="master"
UI_GIT_PATH="inst/shinyApp/ui.R"
UI_LOCAL_PATH="ui.R"
UI_REMOTE_PATH="ui_remote.R"
SERVER_GIT_PATH="inst/shinyApp/server.R"
SERVER_LOCAL_PATH="server.R"
SERVER_REMOTE_PATH="server_remote.R"

# download both the ui and server codes as a remote file
curl -o "${UI_REMOTE_PATH}" "${REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${BRANCH_NAME}/${UI_GIT_PATH}"
curl -o "${SERVER_REMOTE_PATH}" "${REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${BRANCH_NAME}/${SERVER_GIT_PATH}"

# compare the remote and local files for the ui script
if diff -q "${UI_REMOTE_PATH}" "${UI_LOCAL_PATH}" >/dev/null 2>&1; then
  echo "No changes found for ui.R. Checking server.R file."
else
  echo "Changes found and listed below. Updating ui local file..."
  diff -u "${UI_REMOTE_PATH}" "${UI_LOCAL_PATH}" | grep ^[+-]
  cp "${UI_REMOTE_PATH}" "${UI_LOCAL_PATH}"
fi

# compare the remote and local files for the server script
if diff -q "${SERVER_REMOTE_PATH}" "${SERVER_LOCAL_PATH}" >/dev/null 2>&1; then
  echo "No changes found for server.R"
else
  echo "Changes found and listed below. Updating server local file..."
  diff -u "${UI_REMOTE_PATH}" "${UI_LOCAL_PATH}" | grep ^[+-]
  cp "${SERVER_REMOTE_PATH}" "${SERVER_LOCAL_PATH}"
fi

# then finally remove both the ui and server remote files
rm "${UI_REMOTE_PATH}"
rm "${SERVER_REMOTE_PATH}"