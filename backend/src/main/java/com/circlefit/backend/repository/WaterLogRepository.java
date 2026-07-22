package com.circlefit.backend.repository;

import com.circlefit.backend.model.WaterLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Optional;

public interface WaterLogRepository extends JpaRepository<WaterLog, Long> {
    Optional<WaterLog> findByUserIdAndDate(Long userId, LocalDate date);
}
