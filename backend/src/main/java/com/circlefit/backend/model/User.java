package com.circlefit.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String name;
    private Integer age;
    private Double height;
    private Double weight;
    private String gender;
    private String fitnessGoal;
    private Integer dailyCalorieGoal;
    private String profilePicture;
    
    // Group relationship will be added later
    // private Long currentGroupId;

    @Builder.Default
    private Integer totalSteps = 0;
    @Builder.Default
    private Double caloriesBurned = 0.0;
    @Builder.Default
    private Double caloriesConsumed = 0.0;
    @Builder.Default
    private Integer streakCount = 0;

    @Column(updatable = false)
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
