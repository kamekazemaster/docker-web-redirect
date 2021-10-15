#!/bin/bash
if [ -z "$INCLUDE_PATH" ]; then
	INCLUDE_PATH="true"
fi

if [ -z "$INCLUDE_QUERY_STRING" ]; then
	INCLUDE_QUERY_STRING="true"
fi

if [ -z "$REDIRECT_TYPE" ]; then
	REDIRECT_TYPE="permanent"
fi

if [ -z "$REDIRECT_TARGET" ]; then
	echo "Redirect target variable not set (REDIRECT_TARGET)"
	exit 1
else
	# Add http if not set
	if ! [[ $REDIRECT_TARGET =~ ^https?:// ]]; then
		REDIRECT_TARGET="https://$REDIRECT_TARGET"
	fi

	PREPROCESSED_TARGET=${REDIRECT_TARGET};

  if [[ ${INCLUDE_PATH} == "true" ]]; then
    # Add trailing slash if we want to include the path
    if [[ ${PREPROCESSED_TARGET:length-1:1} != "/" ]]; then
      PREPROCESSED_TARGET="PREPROCESSED_TARGET/\$1"
    fi
  fi

  if [[ ${INCLUDE_QUERY_STRING} != "true" ]]; then
    PREPROCESSED_TARGET="$PREPROCESSED_TARGET?"
  fi
fi

# Default to 8080
LISTEN="8080"
# Listen to PORT variable given on Cloud Run Context
if [ ! -z "$PORT" ]; then
	LISTEN="$PORT"
fi

cat <<EOF > /etc/nginx/conf.d/default.conf
server {
	listen ${LISTEN};

	rewrite ^/(.*)\$ ${PREPROCESSED_TARGET} ${REDIRECT_TYPE};
}
EOF


echo "Listening to $LISTEN, Redirecting HTTP requests to ${REDIRECT_TARGET} ..."
if [[ ${INCLUDE_PATH} == "true" ]]; then
  echo "Including the path"
fi
if [[ ${INCLUDE_QUERY_STRING} == "true" ]]; then
  echo "Including the query string"
fi

exec nginx -g "daemon off;"
