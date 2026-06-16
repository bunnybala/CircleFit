package com.circlefit.backend.service;

import com.circlefit.backend.dto.CreateGroupReq;
import com.circlefit.backend.dto.GroupRes;
import com.circlefit.backend.dto.LeaderboardEntry;
import com.circlefit.backend.model.DailyStep;
import com.circlefit.backend.model.Group;
import com.circlefit.backend.model.User;
import com.circlefit.backend.repository.DailyStepRepository;
import com.circlefit.backend.repository.GroupRepository;
import com.circlefit.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final DailyStepRepository dailyStepRepository;

    @Transactional
    public GroupRes createGroup(String username, CreateGroupReq req) {
        User user = getUser(username);

        Group group = Group.builder()
                .name(req.getName())
                .description(req.getDescription())
                .inviteCode(generateInviteCode())
                .createdBy(user)
                .build();
        group.getMembers().add(user);

        return mapToRes(groupRepository.save(group));
    }

    @Transactional
    public GroupRes joinGroup(String username, String inviteCode) {
        User user = getUser(username);
        Group group = groupRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new RuntimeException("Invalid invite code"));

        if (group.getMembers().contains(user)) {
            throw new RuntimeException("You are already a member of this group");
        }
        if (group.getMembers().size() >= group.getMaxMembers()) {
            throw new RuntimeException("Group is full");
        }

        group.getMembers().add(user);
        return mapToRes(groupRepository.save(group));
    }

    @Transactional
    public void leaveGroup(String username, Long groupId) {
        User user = getUser(username);
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("Group not found"));
        group.getMembers().remove(user);
        groupRepository.save(group);
    }

    public List<GroupRes> getMyGroups(String username) {
        User user = getUser(username);
        return groupRepository.findByMember(user).stream()
                .map(this::mapToRes)
                .collect(Collectors.toList());
    }

    public List<LeaderboardEntry> getLeaderboard(Long groupId, String sortBy) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("Group not found"));

        LocalDate today = LocalDate.now();

        // Build today's steps map for all members
        Map<Long, Integer> todayStepsMap = new HashMap<>();
        for (User member : group.getMembers()) {
            int todaySteps = dailyStepRepository
                    .findByUserAndDate(member, today)
                    .map(DailyStep::getSteps)
                    .orElse(0);
            todayStepsMap.put(member.getId(), todaySteps);
        }

        List<LeaderboardEntry> entries = new ArrayList<>();
        for (User member : group.getMembers()) {
            entries.add(LeaderboardEntry.builder()
                    .username(member.getUsername())
                    .name(member.getName() != null ? member.getName() : member.getUsername())
                    .profilePicture(member.getProfilePicture())
                    .totalSteps(member.getTotalSteps() != null ? member.getTotalSteps() : 0)
                    .todaySteps(todayStepsMap.getOrDefault(member.getId(), 0))
                    .caloriesBurned(member.getCaloriesBurned() != null ? member.getCaloriesBurned() : 0.0)
                    .build());
        }

        // Sort by the requested metric
        if ("today".equals(sortBy)) {
            entries.sort(Comparator.comparingInt(LeaderboardEntry::getTodaySteps).reversed());
        } else {
            entries.sort(Comparator.comparingInt(LeaderboardEntry::getTotalSteps).reversed());
        }

        // Assign ranks
        for (int i = 0; i < entries.size(); i++) {
            entries.get(i).setRank(i + 1);
        }

        return entries;
    }

    private GroupRes mapToRes(Group group) {
        return GroupRes.builder()
                .id(group.getId())
                .name(group.getName())
                .description(group.getDescription())
                .inviteCode(group.getInviteCode())
                .createdByUsername(group.getCreatedBy().getUsername())
                .memberCount(group.getMembers().size())
                .maxMembers(group.getMaxMembers())
                .createdAt(group.getCreatedAt())
                .build();
    }

    private User getUser(String identifier) {
        return userRepository.findByUsername(identifier)
                .orElseGet(() -> userRepository.findByEmail(identifier)
                        .orElseThrow(() -> new RuntimeException("User not found")));
    }

    private String generateInviteCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        Random rng = new Random();
        String code;
        do {
            StringBuilder sb = new StringBuilder(6);
            for (int i = 0; i < 6; i++) sb.append(chars.charAt(rng.nextInt(chars.length())));
            code = sb.toString();
        } while (groupRepository.findByInviteCode(code).isPresent());
        return code;
    }
}
