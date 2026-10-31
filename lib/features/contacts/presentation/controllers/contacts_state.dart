import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/contact_request.dart';

enum ContactsStatus {
  initial,
  loading,
  success,
  error,
}

class ContactsState {
  final ContactsStatus status;
  final List<Contact> contacts;
  final List<ContactRequest> incomingRequests;
  final List<ContactRequest> outgoingRequests;
  final UserProfile? searchResult;
  final bool isSearching;
  final String? errorMessage;
  final String? successMessage;

  const ContactsState({
    this.status = ContactsStatus.initial,
    this.contacts = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.searchResult,
    this.isSearching = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == ContactsStatus.loading;

  ContactsState copyWith({
    ContactsStatus? status,
    List<Contact>? contacts,
    List<ContactRequest>? incomingRequests,
    List<ContactRequest>? outgoingRequests,
    UserProfile? searchResult,
    bool clearSearchResult = false,
    bool? isSearching,
    String? errorMessage,
    String? successMessage,
  }) {
    return ContactsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      searchResult: clearSearchResult ? null : (searchResult ?? this.searchResult),
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

