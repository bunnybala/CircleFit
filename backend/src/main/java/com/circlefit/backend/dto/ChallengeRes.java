package com.circlefit.backend.dto;

import com.circlefit.backend.model.Challenge;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class ChallengeRes {
    private Long id;
    private Long groupId;
    private String groupName;
    private String title;
    private String description;
    private Challenge.Type type;
    private int targetValue;
    private LocalDate startDate;
    private LocalDate endDate;
    private Challenge.Status status;
    private String createdByUsername;
    private int participantCount;
    private LocalDateTime createdAt;
}
