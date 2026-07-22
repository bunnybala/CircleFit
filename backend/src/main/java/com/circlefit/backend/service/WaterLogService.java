package com.circlefit.backend.service;

import com.circlefit.backend.dto.WaterLogDto;
import com.circlefit.backend.model.User;
import com.circlefit.backend.model.WaterLog;
import com.circlefit.backend.repository.UserRepository;
import com.circlefit.backend.repository.WaterLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class WaterLogService {

    private final WaterLogRepository waterLogRepository;
    private final UserRepository userRepository;

    public WaterLogDto getWaterLog(String identifier, LocalDate date) {
        User user = findUser(identifier);
        LocalDate targetDate = (date != null) ? date : LocalDate.now();

        WaterLog log = waterLogRepository.findByUserIdAndDate(user.getId(), targetDate)
                .orElse(WaterLog.builder()
                        .user(user)
                        .date(targetDate)
                        .amountMl(0)
                        .goalMl(2000)
                        .build());

        return WaterLogDto.builder()
                .date(log.getDate())
                .amountMl(log.getAmountMl() != null ? log.getAmountMl() : 0)
                .goalMl(log.getGoalMl() != null ? log.getGoalMl() : 2000)
                .build();
    }

    public WaterLogDto logWater(String identifier, WaterLogDto dto) {
        User user = findUser(identifier);
        LocalDate targetDate = (dto.getDate() != null) ? dto.getDate() : LocalDate.now();

        WaterLog log = waterLogRepository.findByUserIdAndDate(user.getId(), targetDate)
                .orElse(WaterLog.builder()
                        .user(user)
                        .date(targetDate)
                        .amountMl(0)
                        .goalMl(2000)
                        .build());

        if (dto.getAmountMl() != null) {
            log.setAmountMl(dto.getAmountMl());
        }
        if (dto.getGoalMl() != null) {
            log.setGoalMl(dto.getGoalMl());
        }

        WaterLog saved = waterLogRepository.save(log);

        return WaterLogDto.builder()
                .date(saved.getDate())
                .amountMl(saved.getAmountMl())
                .goalMl(saved.getGoalMl())
                .build();
    }

    public WaterLogDto resetWater(String identifier, LocalDate date) {
        User user = findUser(identifier);
        LocalDate targetDate = (date != null) ? date : LocalDate.now();

        WaterLog log = waterLogRepository.findByUserIdAndDate(user.getId(), targetDate)
                .orElse(WaterLog.builder()
                        .user(user)
                        .date(targetDate)
                        .amountMl(0)
                        .goalMl(2000)
                        .build());

        log.setAmountMl(0);
        WaterLog saved = waterLogRepository.save(log);

        return WaterLogDto.builder()
                .date(saved.getDate())
                .amountMl(0)
                .goalMl(saved.getGoalMl())
                .build();
    }

    private User findUser(String identifier) {
        return userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));
    }
}
