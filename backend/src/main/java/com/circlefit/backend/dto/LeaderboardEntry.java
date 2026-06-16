package com.circlefit.backend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LeaderboardEntry {
    private int rank;
    private String username;
    private String name;
    private String profilePicture;
    private int totalSteps;
    private int todaySteps;
    private double caloriesBurned;
}
