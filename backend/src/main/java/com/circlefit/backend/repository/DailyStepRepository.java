package com.circlefit.backend.repository;

import com.circlefit.backend.model.DailyStep;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailyStepRepository extends JpaRepository<DailyStep, Long> {
    Optional<DailyStep> findByUserIdAndDate(Long userId, LocalDate date);
    List<DailyStep> findByUserIdAndDateBetweenOrderByDateAsc(Long userId, LocalDate startDate, LocalDate endDate);
    Optional<DailyStep> findByUserAndDate(com.circlefit.backend.model.User user, LocalDate date);
}
