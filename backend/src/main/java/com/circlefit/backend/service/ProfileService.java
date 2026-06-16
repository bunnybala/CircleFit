package com.circlefit.backend.service;

import com.circlefit.backend.dto.UserProfileRes;
import com.circlefit.backend.dto.UserProfileUpdateReq;
import com.circlefit.backend.model.User;
import com.circlefit.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserRepository userRepository;
    private final FirebaseStorageService storageService;

    public UserProfileRes getUserProfile(String identifier) {
        User user = userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));
        return mapToRes(user);
    }

    public UserProfileRes updateUserProfile(String identifier, UserProfileUpdateReq req) {
        User user = userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));

        if (req.getName() != null) user.setName(req.getName());
        if (req.getAge() != null) user.setAge(req.getAge());
        if (req.getHeight() != null) user.setHeight(req.getHeight());
        if (req.getWeight() != null) user.setWeight(req.getWeight());
        if (req.getGender() != null) user.setGender(req.getGender());
        if (req.getFitnessGoal() != null) user.setFitnessGoal(req.getFitnessGoal());
        if (req.getDailyCalorieGoal() != null) user.setDailyCalorieGoal(req.getDailyCalorieGoal());
        if (req.getCaloriesConsumed() != null) user.setCaloriesConsumed(req.getCaloriesConsumed());

        userRepository.save(user);
        return mapToRes(user);
    }

    public UserProfileRes uploadProfileImage(String identifier, MultipartFile file) {
        try {
            User user = userRepository.findByUsername(identifier)
                    .orElseGet(() -> userRepository.findByEmail(identifier)
                            .orElseThrow(() -> new RuntimeException("User not found")));

            String imageUrl = storageService.uploadFile(file, "profiles");
            user.setProfilePicture(imageUrl);
            
            userRepository.save(user);
            return mapToRes(user);
        } catch (Exception e) {
            throw new RuntimeException("Could not upload image: " + e.getMessage());
        }
    }

    private UserProfileRes mapToRes(User user) {
        return UserProfileRes.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .name(user.getName())
                .age(user.getAge())
                .height(user.getHeight())
                .weight(user.getWeight())
                .gender(user.getGender())
                .fitnessGoal(user.getFitnessGoal())
                .dailyCalorieGoal(user.getDailyCalorieGoal())
                .profilePicture(user.getProfilePicture())
                .totalSteps(user.getTotalSteps())
                .caloriesBurned(user.getCaloriesBurned())
                .caloriesConsumed(user.getCaloriesConsumed())
                .streakCount(user.getStreakCount())
                .build();
    }
}
