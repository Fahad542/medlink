import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/views/call/call_screen.dart';
import 'package:medlink/views/call/incoming_call_screen.dart';
import 'package:medlink/utils/utils.dart';

class CallViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  Timer? _pollingTimer;
  bool _isChecking = false;

  /// Global flag: prevents duplicate incoming call screens from socket + polling
  static bool isIncomingCallActive = false;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<String> getCallStatus(String channelName) async {
    try {
      final response = await _apiServices.getCallStatus(channelName);
      if (response != null) {
        // Backend returns { status: 'RINGING' } directly
        if (response['status'] != null) {
          return response['status'].toString();
        }
        // Fallback: wrapped format { success: true, data: { status: ... } }
        if (response['success'] == true && response['data'] != null) {
          return response['data']['status']?.toString() ?? 'UNKNOWN';
        }
      }
    } catch (e) {
      debugPrint("Get call status error: $e");
    }
    return 'UNKNOWN';
  }

  Future<void> updateCallStatus(String channelName, String status) async {
    try {
      await _apiServices.updateCallStatus(channelName, status);
    } catch (e) {
      debugPrint("Update call status error: $e");
    }
  }

  void startPolling(BuildContext context) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isChecking) return;
      // Skip if an incoming call is already being shown (e.g. via socket)
      if (isIncomingCallActive) {
        debugPrint('[CallViewModel] Polling skipped — incoming call already active');
        return;
      }
      _isChecking = true;
      try {
        final response = await _apiServices.checkIncomingCall();
        if (response != null && response['success'] == true) {
          final data = response['data'];
          if (data != null && data['active'] == true && data['data'] != null) {
            final callData = data['data'];

            // Double-check flag again after async call
            if (isIncomingCallActive) return;

            if (context.mounted) {
              _pollingTimer?.cancel();

              final callerId = callData['callerId'] is int
                  ? callData['callerId'] as int
                  : int.tryParse(callData['callerId']?.toString() ?? '');

              isIncomingCallActive = true;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IncomingCallScreen(
                    callerName: callData['callerName'] ?? 'Unknown',
                    callerPhoto: callData['callerPhoto'],
                    channelName: callData['channelName'],
                    token: callData['token'],
                    appId: callData['appId'],
                    callerId: callerId,
                    onDecline: () {
                      startPolling(context);
                    },
                  ),
                ),
              ).then((result) {
                isIncomingCallActive = false;
                if (result == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallScreen(
                        channelName: callData['channelName'],
                        token: callData['token'],
                        appId: callData['appId'],
                        recipientName: callData['callerName'] ?? 'Caller',
                        recipientPhoto: callData['callerPhoto'],
                        isCaller: false,
                        recipientId: callerId,
                      ),
                    ),
                  ).then((_) {
                    if (_pollingTimer?.isActive != true) {
                      startPolling(context);
                    }
                  });
                } else {
                  if (_pollingTimer?.isActive != true) {
                    startPolling(context);
                  }
                }
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking incoming call: $e");
      } finally {
        _isChecking = false;
      }
    });
  }

  Future<void> initiateCall(BuildContext context, int recipientId,
      String recipientName, String? recipientPhoto) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _apiServices.initiateCall(recipientId);
      Navigator.pop(context); // Hide loading

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final channelName = data['channelName'];
        final token = data['token'];
        final appId = data['appId'];
        final recipientIdFromResponse = data['recipientId'];

        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                channelName: channelName,
                token: token,
                appId: appId,
                recipientName: recipientName,
                recipientPhoto: recipientPhoto,
                isCaller: true,
                recipientId: recipientIdFromResponse is int
                    ? recipientIdFromResponse
                    : int.tryParse(recipientIdFromResponse?.toString() ?? ''),
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          Utils.toastMessage(context, "Failed to initiate call", isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        Utils.toastMessage(context, "Error: $e", isError: true);
      }
    }
  }
}
