package com.circlefit.backend.service;

import com.circlefit.backend.dto.CreateGroupReq;
import com.circlefit.backend.dto.GroupRes;
import com.circlefit.backend.model.Group;
import com.circlefit.backend.model.User;
import com.circlefit.backend.repository.DailyStepRepository;
import com.circlefit.backend.repository.GroupRepository;
import com.circlefit.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class GroupServiceTest {

    @Mock
    private GroupRepository groupRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private DailyStepRepository dailyStepRepository;

    @InjectMocks
    private GroupService groupService;

    private User user;
    private CreateGroupReq createGroupReq;
    private Group group;

    @BeforeEach
    void setUp() {
        user = User.builder()
                .id(1L)
                .username("testuser")
                .email("test@circlefit.com")
                .build();

        createGroupReq = new CreateGroupReq();
        createGroupReq.setName("Fitness Club");
        createGroupReq.setDescription("A test group");

        group = Group.builder()
                .id(10L)
                .name("Fitness Club")
                .description("A test group")
                .inviteCode("ABC123")
                .createdBy(user)
                .members(new HashSet<>(Collections.singletonList(user)))
                .build();
    }

    @Test
    void createGroup_Success() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(groupRepository.save(any(Group.class))).thenReturn(group);

        GroupRes response = groupService.createGroup("testuser", createGroupReq);

        assertNotNull(response);
        assertEquals("Fitness Club", response.getName());
        assertEquals("testuser", response.getCreatedByUsername());
        verify(groupRepository, times(1)).save(any(Group.class));
    }

    @Test
    void joinGroup_Success() {
        User newUser = User.builder().id(2L).username("newuser").email("new@test.com").build();
        when(userRepository.findByUsername("newuser")).thenReturn(Optional.of(newUser));
        when(groupRepository.findByInviteCode("ABC123")).thenReturn(Optional.of(group));
        when(groupRepository.save(any(Group.class))).thenReturn(group);

        GroupRes response = groupService.joinGroup("newuser", "ABC123");

        assertNotNull(response);
        assertTrue(group.getMembers().contains(newUser));
        verify(groupRepository, times(1)).save(group);
    }

    @Test
    void joinGroup_InvalidInviteCode_ThrowsException() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(groupRepository.findByInviteCode("INVALID")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> groupService.joinGroup("testuser", "INVALID"));
    }

    @Test
    void joinGroup_AlreadyMember_ThrowsException() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(groupRepository.findByInviteCode("ABC123")).thenReturn(Optional.of(group));

        assertThrows(RuntimeException.class, () -> groupService.joinGroup("testuser", "ABC123"));
    }

    @Test
    void joinGroup_GroupFull_ThrowsException() {
        User newUser = User.builder().id(2L).username("newuser").email("new@test.com").build();
        group.setMaxMembers(1); // Full because user is already in it

        when(userRepository.findByUsername("newuser")).thenReturn(Optional.of(newUser));
        when(groupRepository.findByInviteCode("ABC123")).thenReturn(Optional.of(group));

        assertThrows(RuntimeException.class, () -> groupService.joinGroup("newuser", "ABC123"));
    }

    @Test
    void leaveGroup_Success() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(groupRepository.findById(10L)).thenReturn(Optional.of(group));

        groupService.leaveGroup("testuser", 10L);

        assertFalse(group.getMembers().contains(user));
        verify(groupRepository, times(1)).save(group);
    }

    @Test
    void getMyGroups_ReturnsList() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
        when(groupRepository.findByMember(user)).thenReturn(Collections.singletonList(group));

        List<GroupRes> result = groupService.getMyGroups("testuser");

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Fitness Club", result.get(0).getName());
    }
}
