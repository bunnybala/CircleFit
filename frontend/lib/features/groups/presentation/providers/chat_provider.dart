import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../domain/chat_message.dart';
import '../../data/group_repository.dart';
import 'group_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConnected;
  final int page;
  final bool hasMore;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.isConnected = false,
    this.page = 0,
    this.hasMore = true,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConnected,
    int? page,
    bool? hasMore,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, Map<int, ChatState>>(ChatNotifier.new);

class ChatNotifier extends Notifier<Map<int, ChatState>> {
  final Map<int, StompClient> _clients = {};

  @override
  Map<int, ChatState> build() {
    ref.onDispose(() {
      for (final client in _clients.values) {
        client.deactivate();
      }
    });
    return {};
  }

  void initGroup(int groupId) {
    if (state.containsKey(groupId)) return;
    state = {...state, groupId: ChatState(messages: [])};
    fetchHistory(groupId);
    _connectStomp(groupId);
  }

  Future<void> fetchHistory(int groupId) async {
    final current = state[groupId] ?? ChatState(messages: []);
    if (current.isLoading || !current.hasMore) return;

    _updateState(groupId, current.copyWith(isLoading: true));
    try {
      final repo = ref.read(groupRepositoryProvider);
      final newMessages = await repo.getChatHistory(groupId, current.page, 50);
      
      final updated = state[groupId] ?? current;
      _updateState(groupId, updated.copyWith(
        messages: [...updated.messages, ...newMessages],
        isLoading: false,
        page: updated.page + 1,
        hasMore: newMessages.length == 50,
      ));
    } catch (e) {
      _updateState(groupId, state[groupId]?.copyWith(isLoading: false) ?? current);
    }
  }

  Future<void> _connectStomp(int groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    // final baseUrl = prefs.getString('api_base_url') ?? 'http://192.168.1.5:8081/api';
    final baseUrl = prefs.getString('api_base_url') ?? 'http://192.168.1.12:8081/api';
    
    // Convert http(s) to ws(s)
    String wsUrl = baseUrl.startsWith('https') 
        ? baseUrl.replaceFirst('https', 'wss') 
        : baseUrl.replaceFirst('http', 'ws');
        
    // For Spring Boot with SockJS (.withSockJS() enabled), the raw WebSocket endpoint is always appended with /websocket
    wsUrl = wsUrl.replaceAll('/api', '/ws-chat/websocket');

    final client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) => _onConnect(groupId, frame),
        onWebSocketError: (dynamic error) => print(error.toString()),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _clients[groupId] = client;
    client.activate();
  }

  void _onConnect(int groupId, StompFrame frame) {
    _updateState(groupId, state[groupId]?.copyWith(isConnected: true) ?? ChatState(messages: [], isConnected: true));
    _clients[groupId]?.subscribe(
      destination: '/topic/group/$groupId',
      callback: (frame) {
        if (frame.body != null) {
          final msg = ChatMessage.fromJson(json.decode(frame.body!));
          final current = state[groupId] ?? ChatState(messages: []);
          _updateState(groupId, current.copyWith(messages: [msg, ...current.messages]));
        }
      },
    );
  }

  void sendMessage(int groupId, String content) {
    final client = _clients[groupId];
    if (content.trim().isEmpty || client == null || !client.connected) return;
    
    client.send(
      destination: '/app/chat/$groupId/sendMessage',
      body: json.encode({'content': content}),
    );
  }

  void _updateState(int groupId, ChatState newState) {
    state = {...state, groupId: newState};
  }
}
