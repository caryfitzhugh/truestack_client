This is a wrapper around the websocket and fallback (HTTP) interface to truestack.

Messages passed in the websocket are JSON encoded hashes, with a 'type' value.

For HTTP fallback, the type is pulled out of the blob and appended to the URL "/app/#{type}" - with the rest of the message blob being encoded in JSON and POST'd to the server.

This is supposed to be a small lib, and has tried to stay that way. :)