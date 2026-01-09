// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatDetailHash() => r'25645aeeb1c2e6d317165aa26ee8112a252f803b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider to fetch details for a specific chat
///
/// Copied from [chatDetail].
@ProviderFor(chatDetail)
const chatDetailProvider = ChatDetailFamily();

/// Provider to fetch details for a specific chat
///
/// Copied from [chatDetail].
class ChatDetailFamily extends Family<AsyncValue<ChatModel>> {
  /// Provider to fetch details for a specific chat
  ///
  /// Copied from [chatDetail].
  const ChatDetailFamily();

  /// Provider to fetch details for a specific chat
  ///
  /// Copied from [chatDetail].
  ChatDetailProvider call(
    String chatId,
  ) {
    return ChatDetailProvider(
      chatId,
    );
  }

  @override
  ChatDetailProvider getProviderOverride(
    covariant ChatDetailProvider provider,
  ) {
    return call(
      provider.chatId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatDetailProvider';
}

/// Provider to fetch details for a specific chat
///
/// Copied from [chatDetail].
class ChatDetailProvider extends AutoDisposeFutureProvider<ChatModel> {
  /// Provider to fetch details for a specific chat
  ///
  /// Copied from [chatDetail].
  ChatDetailProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatDetail(
            ref as ChatDetailRef,
            chatId,
          ),
          from: chatDetailProvider,
          name: r'chatDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatDetailHash,
          dependencies: ChatDetailFamily._dependencies,
          allTransitiveDependencies:
              ChatDetailFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
  }) : super.internal();

  final String chatId;

  @override
  Override overrideWith(
    FutureOr<ChatModel> Function(ChatDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatDetailProvider._internal(
        (ref) => create(ref as ChatDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChatModel> createElement() {
    return _ChatDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatDetailProvider && other.chatId == chatId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatDetailRef on AutoDisposeFutureProviderRef<ChatModel> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatDetailProviderElement
    extends AutoDisposeFutureProviderElement<ChatModel> with ChatDetailRef {
  _ChatDetailProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatDetailProvider).chatId;
}

String _$chatsHash() => r'0c7f71d104df61740a2d927755f479d18682289d';

/// Chats list provider with auto-refresh on page return
///
/// Copied from [Chats].
@ProviderFor(Chats)
final chatsProvider =
    AutoDisposeAsyncNotifierProvider<Chats, List<ChatModel>>.internal(
  Chats.new,
  name: r'chatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Chats = AutoDisposeAsyncNotifier<List<ChatModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
