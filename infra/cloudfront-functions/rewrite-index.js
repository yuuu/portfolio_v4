// CloudFront only appends default_root_object (index.html) to the bare "/"
// path, not to subdirectories. Bridgetown's pretty permalinks emit
// /profile/index.html for /profile/, so without this the origin request
// for /profile/ 404s. This mirrors AWS's documented URI-rewrite pattern.
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith("/")) {
    request.uri += "index.html";
  } else if (!uri.includes(".")) {
    request.uri += "/index.html";
  }

  return request;
}
