package com.circlefit.backend.repository;

import com.circlefit.backend.model.Group;
import com.circlefit.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GroupRepository extends JpaRepository<Group, Long> {
    Optional<Group> findByInviteCode(String inviteCode);

    @Query("SELECT g FROM Group g JOIN g.members m WHERE m = :user")
    List<Group> findByMember(@Param("user") User user);
}
