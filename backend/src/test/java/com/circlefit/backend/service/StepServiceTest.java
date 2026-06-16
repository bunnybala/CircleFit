package com.circlefit.backend.service;

import com.circlefit.backend.dto.StepSyncReq;
import com.circlefit.backend.model.DailyStep;
import com.circlefit.backend.model.User;
import com.circlefit.backend.repository.DailyStepRepository;
import com.circlefit.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class StepServiceTest {

    @Mock
    private DailyStepRepository dailyStepRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private StepService stepService;

    private User user;
    private StepSyncReq syncReq;

    @BeforeEach
    void setUp() {
        user = User.builder()
                .id(1L)
                .username("testuser")
                .email("test@circlefit.com")
                .totalSteps(1000)
                .caloriesBurned(50.0)
                .updatedAt(LocalDateTime.now())
                .build();

        syncReq = new StepSyncReq();
        syncReq.setDate(LocalDate.now());
        syncReq.setSteps(2000);
        syncReq.setDistance(1.5);
        syncReq.setCalories(100.0);
    }

    @Test
    void syncSteps_UserNotFound_ThrowsException() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("testuser")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> stepService.syncSteps("testuser", Collections.singletonList(syncReq)));
    }

    @Test
    void syncSteps_NewDailyStep_Saves() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(dailyStepRepository.findByUserIdAndDate(1L, LocalDate.now())).thenReturn(Optional.empty());

        stepService.syncSteps("testuser", Collections.singletonList(syncReq));

        verify(dailyStepRepository, times(1)).save(any(DailyStep.class));
        verify(userRepository, times(1)).save(any(User.class));
        assertEquals(2000, user.getTotalSteps());
        assertEquals(100.0, user.getCaloriesBurned());
    }

    @Test
    void syncSteps_ExistingDailyStep_UpdatesIfGreater() {
        DailyStep existingStep = DailyStep.builder()
                .id(10L)
                .user(user)
                .date(LocalDate.now())
                .steps(1500)
                .distance(1.0)
                .calories(75.0)
                .build();

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(dailyStepRepository.findByUserIdAndDate(1L, LocalDate.now())).thenReturn(Optional.of(existingStep));

        stepService.syncSteps("testuser", Collections.singletonList(syncReq));

        verify(dailyStepRepository, times(1)).save(existingStep);
        assertEquals(2000, existingStep.getSteps());
        assertEquals(1.5, existingStep.getDistance());
        assertEquals(100.0, existingStep.getCalories());
    }

    @Test
    void syncSteps_ExistingDailyStep_DoesNotUpdateIfLesser() {
        DailyStep existingStep = DailyStep.builder()
                .id(10L)
                .user(user)
                .date(LocalDate.now())
                .steps(3000)
                .distance(2.5)
                .calories(150.0)
                .build();

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(dailyStepRepository.findByUserIdAndDate(1L, LocalDate.now())).thenReturn(Optional.of(existingStep));

        stepService.syncSteps("testuser", Collections.singletonList(syncReq));

        verify(dailyStepRepository, never()).save(any(DailyStep.class));
    }

    @Test
    void getWeeklyStats_ReturnsList() {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(6);
        List<DailyStep> mockSteps = Collections.singletonList(new DailyStep());

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(dailyStepRepository.findByUserIdAndDateBetweenOrderByDateAsc(1L, startDate, endDate)).thenReturn(mockSteps);

        List<DailyStep> result = stepService.getWeeklyStats("testuser");

        assertNotNull(result);
        assertEquals(1, result.size());
    }
}
