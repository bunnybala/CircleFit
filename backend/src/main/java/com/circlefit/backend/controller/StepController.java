package com.circlefit.backend.controller;

import com.circlefit.backend.dto.ApiResponse;
import com.circlefit.backend.dto.StepSyncReq;
import com.circlefit.backend.model.DailyStep;
import com.circlefit.backend.service.StepService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/steps")
@RequiredArgsConstructor
public class StepController {

    private final StepService stepService;

    @PostMapping("/sync")
    public ResponseEntity<ApiResponse> syncSteps(Authentication authentication, @RequestBody List<StepSyncReq> syncReqs) {
        stepService.syncSteps(authentication.getName(), syncReqs);
        return ResponseEntity.ok(new ApiResponse(true, "Steps synced successfully"));
    }

    @GetMapping("/weekly")
    public ResponseEntity<List<DailyStep>> getWeeklyStats(Authentication authentication) {
        return ResponseEntity.ok(stepService.getWeeklyStats(authentication.getName()));
    }
}
