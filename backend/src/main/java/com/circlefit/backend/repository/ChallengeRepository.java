package com.circlefit.backend.repository;

import com.circlefit.backend.model.Challenge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface ChallengeRepository extends JpaRepository<Challenge, Long> {
    List<Challenge> findByGroupId(Long groupId);

    @Query("SELECT c FROM Challenge c WHERE c.group.id = :groupId AND c.status = 'ACTIVE' AND c.endDate >= :today")
    List<Challenge> findActiveByGroupId(@Param("groupId") Long groupId, @Param("today") LocalDate today);
}
