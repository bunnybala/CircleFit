package com.circlefit.backend.service;

import com.circlefit.backend.dto.StepSyncReq;
import com.circlefit.backend.model.DailyStep;
import com.circlefit.backend.model.User;
import com.circlefit.backend.repository.DailyStepRepository;
import com.circlefit.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StepService {

    private final DailyStepRepository dailyStepRepository;
    private final UserRepository userRepository;

    public void syncSteps(String identifier, List<StepSyncReq> syncReqs) {
        User user = userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));

        for (StepSyncReq req : syncReqs) {
            DailyStep step = dailyStepRepository.findByUserIdAndDate(user.getId(), req.getDate())
                    .orElse(DailyStep.builder()
                            .user(user)
                            .date(req.getDate())
                            .build());

            // Update only if local steps from flutter are greater than what we have
            if (step.getSteps() == null || req.getSteps() > step.getSteps()) {
                step.setSteps(req.getSteps());
                step.setDistance(req.getDistance());
                step.setCalories(req.getCalories());
                dailyStepRepository.save(step);
            }
            
            // Update User's today stats if date is today
            if (req.getDate().equals(LocalDate.now())) {
                boolean isNewDay = user.getUpdatedAt() == null || 
                                   !user.getUpdatedAt().toLocalDate().equals(LocalDate.now());
                
                if (isNewDay) {
                    // It is a new day! Overwrite stats directly with the new day's initial values
                    user.setTotalSteps(req.getSteps());
                    user.setCaloriesBurned(req.getCalories());
                    userRepository.save(user);
                } else if (user.getTotalSteps() == null || req.getSteps() > user.getTotalSteps()) {
                    // Same day, update only if steps are greater than currently saved
                    user.setTotalSteps(req.getSteps());
                    user.setCaloriesBurned(req.getCalories());
                    userRepository.save(user);
                }
            }
        }
    }

    public List<DailyStep> getWeeklyStats(String identifier) {
        User user = userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(6);
        return dailyStepRepository.findByUserIdAndDateBetweenOrderByDateAsc(user.getId(), startDate, endDate);
    }

    public DailyStep getTodayStep(String identifier) {
        User user = userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));
        return dailyStepRepository.findByUserIdAndDate(user.getId(), LocalDate.now())
                .orElse(DailyStep.builder().user(user).date(LocalDate.now()).steps(0).calories(0.0).distance(0.0).build());
    }
}
