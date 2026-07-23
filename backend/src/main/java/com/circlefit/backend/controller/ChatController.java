package com.circlefit.backend.controller;

import com.circlefit.backend.dto.ChatMessageReq;
import com.circlefit.backend.dto.ChatMessageRes;
import com.circlefit.backend.model.ChatMessage;
import com.circlefit.backend.model.Group;
import com.circlefit.backend.model.User;
import com.circlefit.backend.repository.ChatMessageRepository;
import com.circlefit.backend.repository.GroupRepository;
import com.circlefit.backend.repository.UserRepository;
import com.circlefit.backend.service.ProfanityFilterService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.transaction.annotation.Transactional;

@RestController
@RequiredArgsConstructor
public class ChatController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatMessageRepository chatMessageRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final ProfanityFilterService profanityFilterService;

    @MessageMapping("/chat/{groupId}/sendMessage")
    @Transactional
    public void sendMessage(@DestinationVariable Long groupId, @Payload ChatMessageReq req, Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return;
        }

        // Intercept and block vulgar messages
        if (req != null && profanityFilterService.containsProfanity(req.getContent())) {
            // Send feedback ONLY to the sender via a private WebSocket queue
            messagingTemplate.convertAndSendToUser(
                authentication.getName(),
                "/queue/errors",
                "Your message was blocked because it contained inappropriate language."
            );
            return;
        }

        String username = authentication.getName();
        User sender = userRepository.findByUsername(username).orElse(null);
        Group group = groupRepository.findById(groupId).orElse(null);

        if (sender == null || group == null) {
            return;
        }

        // Verify sender is in the group
        if (!group.getMembers().contains(sender)) {
            return;
        }

        ChatMessage message = new ChatMessage();
        message.setGroup(group);
        message.setSender(sender);
        message.setContent(req.getContent());
        message.setTimestamp(LocalDateTime.now());

        chatMessageRepository.save(message);

        ChatMessageRes response = ChatMessageRes.builder()
                .id(message.getId())
                .groupId(group.getId())
                .senderId(sender.getId())
                .senderName(sender.getUsername())
                .content(message.getContent())
                .timestamp(message.getTimestamp())
                .build();

        messagingTemplate.convertAndSend("/topic/group/" + groupId, response);
    }

    @GetMapping("/api/groups/{groupId}/chat/history")
    @Transactional(readOnly = true)
    public ResponseEntity<List<ChatMessageRes>> getChatHistory(
            @PathVariable Long groupId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<ChatMessage> messagePage = chatMessageRepository.findByGroupIdOrderByTimestampDesc(groupId, pageable);

        List<ChatMessageRes> response = messagePage.getContent().stream().map(message ->
                ChatMessageRes.builder()
                        .id(message.getId())
                        .groupId(message.getGroup().getId())
                        .senderId(message.getSender().getId())
                        .senderName(message.getSender().getUsername())
                        .content(message.getContent())
                        .timestamp(message.getTimestamp())
                        .build()
        ).collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }
}
