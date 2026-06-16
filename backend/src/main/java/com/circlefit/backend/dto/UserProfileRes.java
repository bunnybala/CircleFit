package com.circlefit.backend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserProfileRes {
    private Long id;
    private String username;
    private String email;
    private String name;
    private Integer age;
    private Double height;
    private Double weight;
    private String gender;
    private String fitnessGoal;
    private Integer dailyCalorieGoal;
    private String profilePicture;
    private Integer totalSteps;
    private Double caloriesBurned;
    private Double caloriesConsumed;
    private Integer streakCount;
}
