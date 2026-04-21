import 'package:flutter/material.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:intl/intl.dart';
import '../../../data/network/api_services.dart';

class AppointmentViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentModel> get pastAppointments => _pastAppointments;
  List<AppointmentModel> get cancelledAppointments => _cancelledAppointments;

  List<String> _bookedSlots = [];
  List<DateTimeRange> _bookedRanges = [];
  bool _isLoadingBookedSlots = false;
  
  List<String> get bookedSlots => _bookedSlots;
  List<DateTimeRange> get bookedRanges => _bookedRanges;
  bool get isLoadingBookedSlots => _isLoadingBookedSlots;

  // Backwards compatibility alias
  List<AppointmentModel> get appointments => _upcomingAppointments;

  final ApiServices _apiService = ApiServices();

  Future<void> fetchAppointments(String patientId,
      {String status = 'upcoming'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<AppointmentModel> fetched = [];
      if (status == 'upcoming') {
        final response = await _apiService.getUpcomingAppointments();
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'];
          fetched =
              data.map((json) => AppointmentModel.fromJson(json)).toList();
        }
        AppointmentModel.sortByCreatedAtDescending(fetched);
        _upcomingAppointments = fetched;
      } else if (status == 'cancelled') {
        final response = await _apiService.getCancelledAppointments();
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'];
          fetched =
              data.map((json) => AppointmentModel.fromJson(json)).toList();
        }
        AppointmentModel.sortByCreatedAtDescending(fetched);
        _cancelledAppointments = fetched;
      } else if (status == 'past') {
        final response = await _apiService.getPastAppointments();
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'];
          fetched =
              data.map((json) => AppointmentModel.fromJson(json)).toList();
        }
        AppointmentModel.sortByCreatedAtDescending(fetched);
        _pastAppointments = fetched;
      }
    } catch (e) {
      debugPrint("ViewModel Error fetching $status appointments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calls PATCH /patient/appointments/:id/confirm then refetches upcoming list.
  Future<bool> confirmPatientAppointment(
    String appointmentId,
    String patientId,
  ) async {
    try {
      final response =
          await _apiService.confirmPatientAppointment(appointmentId);
      final ok = response != null && response['success'] == true;
      if (ok) {
        await fetchAppointments(patientId, status: 'upcoming');
      }
      return ok;
    } catch (e) {
      debugPrint('Error confirming appointment: $e');
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      final response =
          await _apiService.cancelAppointment(appointmentId, reason);
      if (response != null && response['success'] == true) {
        _upcomingAppointments.removeWhere((a) => a.id == appointmentId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error cancelling appointment: $e");
      return false;
    }
  }

  Future<bool> completeAppointment(String appointmentId) async {
    try {
      final response = await _apiService.completeAppointment(appointmentId);
      if (response != null && response['success'] == true) {
        final upcomingIndex =
            _upcomingAppointments.indexWhere((a) => a.id == appointmentId);
        if (upcomingIndex != -1) {
          final appointment = _upcomingAppointments.removeAt(upcomingIndex);
          _pastAppointments.add(appointment);
          AppointmentModel.sortByCreatedAtDescending(_pastAppointments);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error completing appointment: $e");
      return false;
    }
  }

  Future<void> loadUpcomingAppointments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getUpcomingAppointments();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _upcomingAppointments =
            data.map((json) => AppointmentModel.fromJson(json)).toList();
        AppointmentModel.sortByCreatedAtDescending(_upcomingAppointments);
      }
    } catch (e) {
      debugPrint("Error loading upcoming appointments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> bookAppointment({
    required DoctorModel doctor,
    required DateTime date,
    required String time,
    required String patientId,
    String description = "General Consultation",
    AppointmentType consultationType = AppointmentType.inPerson,
  }) async {
    DateTime? parsedStartTime;
    try {
      parsedStartTime = DateFormat("h:mm a").parse(time);
    } catch (e) {
      parsedStartTime = DateFormat("HH:mm").parse(time);
    }

    // User-selected wall time on the chosen calendar day (device timezone).
    final localStart = DateTime(
      date.year,
      date.month,
      date.day,
      parsedStartTime.hour,
      parsedStartTime.minute,
    );
    final localEnd =
        localStart.add(Duration(minutes: doctor.sessionDuration));

    // Backend uses Date.UTC(date, startTime) — it expects UTC components, not local.
    // Convert so My Appointments shows the same clock time the user picked.
    final utcStart = localStart.toUtc();
    final utcEnd = localEnd.toUtc();

    final appointmentData = {
      "doctorId": doctor.id,
      "date": DateFormat('yyyy-MM-dd').format(utcStart),
      "startTime": DateFormat('HH:mm').format(utcStart),
      "endTime": DateFormat('HH:mm').format(utcEnd),
      "description": description.isEmpty ? "General Consultation" : description,
      "consultKind": consultationType.consultKindValue,
    };

    try {
      final result = await _apiService.bookAppointment(appointmentData);

      if (result != null && result['success'] == true) {
        // DRILL DOWN: Backend returns { success: true, data: { success: true, data: { ...stripeKeys } } }
        final outerData = result['data'];
        final stripeData = (outerData is Map && outerData['success'] == true)
            ? outerData['data']
            : outerData;

        return {
          'success': true,
          'appointmentId': "pending",
          'paymentData': stripeData,
          'message': 'Booking initiated. Please complete payment.'
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to book appointment'
        };
      }
    } catch (e) {
      debugPrint("Booking error: $e");
      return {
        'success': false,
        'message': 'An error occurred during booking: $e'
      };
    }
  }

  Future<void> fetchBookedSlots(
    String doctorId,
    String date, {
    String? excludeAppointmentId,
  }) async {
    _isLoadingBookedSlots = true;
    _bookedSlots.clear();
    _bookedRanges.clear();
    notifyListeners();

    try {
      final response = await _apiService.getBookedSlots(
        doctorId,
        date,
        excludeAppointmentId: excludeAppointmentId,
      );
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        // Same instants as API; use device-local wall time for labels and overlap checks.
        _bookedRanges = data.map((json) {
          final start =
              DateTime.parse(json['scheduledStart'].toString()).toLocal();
          final end = json['scheduledEnd'] != null
              ? DateTime.parse(json['scheduledEnd'].toString()).toLocal()
              : start;
          return DateTimeRange(start: start, end: end);
        }).toList();

        _bookedSlots = _bookedRanges.map((range) {
          return DateFormat('hh:mm a').format(range.start);
        }).toList();
        
        debugPrint("[AppointmentViewModel] Total booked ranges for $date: ${_bookedRanges.length}");
      }
    } catch (e) {
      debugPrint("Error fetching booked slots: $e");
    } finally {
      _isLoadingBookedSlots = false;
      notifyListeners();
    }
  }
}
