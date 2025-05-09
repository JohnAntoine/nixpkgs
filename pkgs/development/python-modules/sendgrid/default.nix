{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flask,
  pytestCheckHook,
  python-http-client,
  pythonOlder,
  pyyaml,
  starkbank-ecdsa,
  six,
  werkzeug,
}:

buildPythonPackage rec {
  pname = "sendgrid";
  version = "6.11.0";
  format = "setuptools";

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = pname;
    repo = "sendgrid-python";
    tag = version;
    hash = "sha256-wcQLdU80pcyEplzL8lnehtToqYiTrX1n5TjmK5zturE=";
  };

  propagatedBuildInputs = [
    python-http-client
    starkbank-ecdsa
    six
  ];

  nativeCheckInputs = [
    flask
    pytestCheckHook
    pyyaml
    werkzeug
  ];

  disabledTestPaths = [
    # Exclude tests that require network access
    "test/integ/test_sendgrid.py"
    "live_test.py"
  ];

  pythonImportsCheck = [ "sendgrid" ];

  meta = with lib; {
    description = "Python client for SendGrid";
    homepage = "https://github.com/sendgrid/sendgrid-python";
    changelog = "https://github.com/sendgrid/sendgrid-python/blob/${version}/CHANGELOG.md";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
