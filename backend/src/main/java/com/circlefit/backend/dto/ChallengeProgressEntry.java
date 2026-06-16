package com.circlefit.backend.dto;

import com.circlefit.backend.model.Challenge;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ChallengeProgressEntry {
    private String username;
    private String name;
    private String profilePicture;
    private int currentProgress;
    private int targetValue;
    private Challenge.Type type;
    private double percentComplete;
}
