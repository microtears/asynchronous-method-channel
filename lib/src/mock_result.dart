/// Mock method call result callback.
class MockResult {
  final void Function<T>(T any) _successCallback;
  final void Function(
          String errorCode, String errorMessage, String errorDetails)
      _errorCallback;

  /// Mock method call result callback.
  ///
  /// [_successCallback] is a callback to handle a successful asynchronous result.
  /// [_errorCallback] is a callback to handle a wrong asynchronous result.
  MockResult(this._successCallback, this._errorCallback);

  /// Handles a successful asynchronous result.
  void success<T>(T result) {
    _successCallback(result);
  }

  /// Handles a wrong asynchronous result.
  ///
  /// [errorCode] is an error code.
  /// [errorMessage] is a human-readable error message, possibly null.
  /// [errorDetails] is error details, possibly null.
  void error(String errorCode, String errorMessage, String errorDetails) {
    _errorCallback(errorCode, errorMessage, errorDetails);
  }
}
