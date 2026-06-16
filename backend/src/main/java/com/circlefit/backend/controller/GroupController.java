package com.circlefit.backend.controller;

import com.circlefit.backend.dto.CreateGroupReq;
import com.circlefit.backend.dto.GroupRes;
import com.circlefit.backend.dto.LeaderboardEntry;
import com.circlefit.backend.service.GroupService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    @PostMapping
    public ResponseEntity<GroupRes> createGroup(
            Authentication auth, @RequestBody CreateGroupReq req) {
        return ResponseEntity.ok(groupService.createGroup(auth.getName(), req));
    }

    @PostMapping("/join")
    public ResponseEntity<GroupRes> joinGroup(
            Authentication auth, @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(groupService.joinGroup(auth.getName(), body.get("inviteCode")));
    }

    @DeleteMapping("/{id}/leave")
    public ResponseEntity<Void> leaveGroup(Authentication auth, @PathVariable Long id) {
        groupService.leaveGroup(auth.getName(), id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/my")
    public ResponseEntity<List<GroupRes>> getMyGroups(Authentication auth) {
        return ResponseEntity.ok(groupService.getMyGroups(auth.getName()));
    }

    @GetMapping("/{id}/leaderboard")
    public ResponseEntity<List<LeaderboardEntry>> getLeaderboard(
            @PathVariable Long id,
            @RequestParam(defaultValue = "total") String sortBy) {
        return ResponseEntity.ok(groupService.getLeaderboard(id, sortBy));
    }
}
