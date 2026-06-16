package com.circlefit.backend.service;

import com.circlefit.backend.dto.*;
import com.circlefit.backend.model.*;
import com.circlefit.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChallengeService {

    private final ChallengeRepository challengeRepository;
    private final ChallengeParticipantRepository participantRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final DailyStepRepository dailyStepRepository;

    @Transactional
    public ChallengeRes createChallenge(String username, CreateChallengeReq req) {
        User user = getUser(username);
        Group group = groupRepository.findById(req.getGroupId())
                .orElseThrow(() -> new RuntimeException("Group not found"));

        // Only group members can create challenges
        if (!group.getMembers().contains(user)) {
            throw new RuntimeException("You must be a group member to create a challenge");
        }

        Challenge challenge = Challenge.builder()
                .group(group)
                .title(req.getTitle())
                .description(req.getDescription())
                .type(req.getType())
                .targetValue(req.getTargetValue())
                .startDate(req.getStartDate())
                .endDate(req.getEndDate())
                .createdBy(user)
                .build();

        return mapToRes(challengeRepository.save(challenge));
    }

    @Transactional
    public void joinChallenge(String username, Long challengeId) {
        User user = getUser(username);
        Challenge challenge = getChallenge(challengeId);

        // Must be group member
        if (!challenge.getGroup().getMembers().contains(user)) {
            throw new RuntimeException("You must be a group member to join this challenge");
        }

        if (participantRepository.existsByChallengeIdAndUserId(challengeId, user.getId())) {
            throw new RuntimeException("You have already joined this challenge");
        }

        ChallengeParticipant participant = ChallengeParticipant.builder()
                .challenge(challenge)
                .user(user)
                .build();
        participantRepository.save(participant);
    }

    public List<ChallengeRes> getChallengesByGroup(Long groupId) {
        return challengeRepository.findByGroupId(groupId).stream()
                .map(this::mapToRes)
                .collect(Collectors.toList());
    }

    public List<ChallengeProgressEntry> getChallengeProgress(Long challengeId) {
        Challenge challenge = getChallenge(challengeId);
        List<ChallengeParticipant> participants = participantRepository.findByChallengeId(challengeId);

        return participants.stream().map(p -> {
            User u = p.getUser();
            
            // Query and sum daily steps/calories over the active challenge duration
            List<DailyStep> dailySteps = dailyStepRepository.findByUserIdAndDateBetweenOrderByDateAsc(
                    u.getId(), challenge.getStartDate(), challenge.getEndDate());
            
            int progress = 0;
            if (challenge.getType() == Challenge.Type.STEPS) {
                progress = dailySteps.stream()
                        .mapToInt(ds -> ds.getSteps() != null ? ds.getSteps() : 0)
                        .sum();
            } else {
                progress = (int) dailySteps.stream()
                        .mapToDouble(ds -> ds.getCalories() != null ? ds.getCalories() : 0.0)
                        .sum();
            }

            double pct = challenge.getTargetValue() > 0
                    ? Math.min(100.0, (progress * 100.0) / challenge.getTargetValue())
                    : 0;

            return ChallengeProgressEntry.builder()
                    .username(u.getUsername())
                    .name(u.getName() != null ? u.getName() : u.getUsername())
                    .profilePicture(u.getProfilePicture())
                    .currentProgress(progress)
                    .targetValue(challenge.getTargetValue())
                    .type(challenge.getType())
                    .percentComplete(pct)
                    .build();
        }).sorted((a, b) -> Integer.compare(b.getCurrentProgress(), a.getCurrentProgress()))
          .collect(Collectors.toList());
    }

    private ChallengeRes mapToRes(Challenge c) {
        return ChallengeRes.builder()
                .id(c.getId())
                .groupId(c.getGroup().getId())
                .groupName(c.getGroup().getName())
                .title(c.getTitle())
                .description(c.getDescription())
                .type(c.getType())
                .targetValue(c.getTargetValue())
                .startDate(c.getStartDate())
                .endDate(c.getEndDate())
                .status(c.getStatus())
                .createdByUsername(c.getCreatedBy().getUsername())
                .participantCount(participantRepository.findByChallengeId(c.getId()).size())
                .createdAt(c.getCreatedAt())
                .build();
    }

    private User getUser(String identifier) {
        return userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));
    }

    private Challenge getChallenge(Long id) {
        return challengeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Challenge not found"));
    }
}
