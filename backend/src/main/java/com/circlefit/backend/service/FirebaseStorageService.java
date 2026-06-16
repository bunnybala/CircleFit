package com.circlefit.backend.service;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.firebase.cloud.StorageClient;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
public class FirebaseStorageService {

    public String uploadFile(MultipartFile file, String folder) throws IOException {
        try {
            Bucket bucket = StorageClient.getInstance().bucket();
            if (bucket == null || bucket.getName() == null) {
                throw new RuntimeException("Firebase Storage bucket is not configured or initialized.");
            }

            String fileName = folder + "/" + UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
            
            Blob blob = bucket.create(fileName, file.getBytes(), file.getContentType());
            
            return "https://firebasestorage.googleapis.com/v0/b/" + bucket.getName() + "/o/" + 
                   fileName.replace("/", "%2F") + "?alt=media";
        } catch (Exception e) {
            System.err.println("Firebase upload failed: " + e.getMessage() + ". Falling back to local storage.");
            return uploadFileLocally(file);
        }
    }

    private String uploadFileLocally(MultipartFile file) throws IOException {
        Path uploadPath = Paths.get("uploads");
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        String uniqueFileName = UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
        Path filePath = uploadPath.resolve(uniqueFileName);
        Files.write(filePath, file.getBytes());

        // Construct dynamically the full server URL using the incoming request context
        return ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/uploads/")
                .path(uniqueFileName)
                .toUriString();
    }
}
