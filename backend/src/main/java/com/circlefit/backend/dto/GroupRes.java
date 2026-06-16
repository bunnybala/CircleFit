package com.circlefit.backend.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class GroupRes {
    private Long id;
    private String name;
    private String description;
    private String inviteCode;
    private String createdByUsername;
    private int memberCount;
    private int maxMembers;
    private LocalDateTime createdAt;
}
