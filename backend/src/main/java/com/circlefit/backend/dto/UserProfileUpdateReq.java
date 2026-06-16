package com.circlefit.backend.dto;

import lombok.Data;

@Data
public class UserProfileUpdateReq {
    private String name;
    private Integer age;
    private Double height;
    private Double weight;
    private String gender;
    private String fitnessGoal;
    private Integer dailyCalorieGoal;
    private Double caloriesConsumed;
}
