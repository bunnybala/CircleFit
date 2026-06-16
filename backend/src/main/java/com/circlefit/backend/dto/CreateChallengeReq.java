package com.circlefit.backend.dto;

import com.circlefit.backend.model.Challenge;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateChallengeReq {
    private Long groupId;
    private String title;
    private String description;
    private Challenge.Type type;
    private int targetValue;
    private LocalDate startDate;
    private LocalDate endDate;
}
