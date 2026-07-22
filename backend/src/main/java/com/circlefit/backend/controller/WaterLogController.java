package com.circlefit.backend.controller;

import com.circlefit.backend.dto.WaterLogDto;
import com.circlefit.backend.service.WaterLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/water")
@RequiredArgsConstructor
public class WaterLogController {

    private final WaterLogService waterLogService;

    @GetMapping
    public ResponseEntity<WaterLogDto> getWaterLog(
            Authentication authentication,
            @RequestParam(value = "date", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(waterLogService.getWaterLog(authentication.getName(), date));
    }

    @PostMapping("/log")
    public ResponseEntity<WaterLogDto> logWater(
            Authentication authentication,
            @RequestBody WaterLogDto dto) {
        return ResponseEntity.ok(waterLogService.logWater(authentication.getName(), dto));
    }

    @PostMapping("/reset")
    public ResponseEntity<WaterLogDto> resetWater(
            Authentication authentication,
            @RequestParam(value = "date", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(waterLogService.resetWater(authentication.getName(), date));
    }
}
