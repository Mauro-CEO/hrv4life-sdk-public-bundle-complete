/// Status of the HRV monitor.
enum HrvMonitorStatus {
  /// Controller has not been initialized yet.
  uninitialized,

  /// Controller is initializing (setting up camera).
  initializing,

  /// Controller is ready to start measurement.
  ready,

  /// Waiting for user to place finger on camera.
  waitingForFinger,

  /// Actively measuring HRV.
  measuring,

  /// Measurement paused (finger removed but data preserved).
  paused,

  /// Processing captured data with API.
  processing,

  /// Measurement completed successfully.
  completed,

  /// An error occurred.
  error,
}
