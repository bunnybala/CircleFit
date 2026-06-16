package com.circlefit.backend.controller;

import com.circlefit.backend.dto.UserProfileRes;
import com.circlefit.backend.dto.UserProfileUpdateReq;
import com.circlefit.backend.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    @GetMapping
    public ResponseEntity<UserProfileRes> getProfile(Authentication authentication) {
        return ResponseEntity.ok(profileService.getUserProfile(authentication.getName()));
    }

    @PutMapping
    public ResponseEntity<UserProfileRes> updateProfile(Authentication authentication, @RequestBody UserProfileUpdateReq req) {
        return ResponseEntity.ok(profileService.updateUserProfile(authentication.getName(), req));
    }

    @PostMapping("/image")
    public ResponseEntity<UserProfileRes> uploadImage(Authentication authentication, @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(profileService.uploadProfileImage(authentication.getName(), file));
    }
}
