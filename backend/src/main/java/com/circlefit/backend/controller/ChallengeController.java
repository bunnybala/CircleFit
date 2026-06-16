package com.circlefit.backend.controller;

import com.circlefit.backend.dto.*;
import com.circlefit.backend.service.ChallengeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/challenges")
@RequiredArgsConstructor
public class ChallengeController {

    private final ChallengeService challengeService;

    @PostMapping
    public ResponseEntity<ChallengeRes> createChallenge(
            Authentication auth, @RequestBody CreateChallengeReq req) {
        return ResponseEntity.ok(challengeService.createChallenge(auth.getName(), req));
    }

    @PostMapping("/{id}/join")
    public ResponseEntity<Void> joinChallenge(Authentication auth, @PathVariable Long id) {
        challengeService.joinChallenge(auth.getName(), id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/group/{groupId}")
    public ResponseEntity<List<ChallengeRes>> getChallengesByGroup(@PathVariable Long groupId) {
        return ResponseEntity.ok(challengeService.getChallengesByGroup(groupId));
    }

    @GetMapping("/{id}/progress")
    public ResponseEntity<List<ChallengeProgressEntry>> getProgress(@PathVariable Long id) {
        return ResponseEntity.ok(challengeService.getChallengeProgress(id));
    }
}
