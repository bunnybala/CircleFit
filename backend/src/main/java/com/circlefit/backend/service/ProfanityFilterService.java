package com.circlefit.backend.service;

import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class ProfanityFilterService {

    private static final Set<String> BLACKLIST = new HashSet<>(Arrays.asList(
        // Common vulgar/offensive terms
        "abuse", "ass", "asshole", "bitch", "bastard", "crap", "cunt", "dick", "fucker", "fucking", 
        "fuck", "nigger", "piss", "pussy", "shit", "slut", "whore"
    ));

    private static final Map<Character, Character> LEET_MAP = new HashMap<>();
    static {
        LEET_MAP.put('0', 'o');
        LEET_MAP.put('1', 'i');
        LEET_MAP.put('!', 'i');
        LEET_MAP.put('|', 'i');
        LEET_MAP.put('3', 'e');
        LEET_MAP.put('4', 'a');
        LEET_MAP.put('@', 'a');
        LEET_MAP.put('5', 's');
        LEET_MAP.put('$', 's');
        LEET_MAP.put('7', 't');
        LEET_MAP.put('8', 'b');
        LEET_MAP.put('9', 'g');
    }

    public boolean containsProfanity(String text) {
        if (text == null || text.trim().isEmpty()) {
            return false;
        }

        // 1. Normalize character substitutions (Leetspeak folding & removing punctuation)
        String normalized = normalizeText(text);

        // 2. Tokenize and search for bad words
        String[] words = normalized.split("\\s+");
        for (String word : words) {
            if (BLACKLIST.contains(word)) {
                return true;
            }
        }

        // 3. Search for substrings / compacted bad words (e.g. "f_u_c_k" or "f.u.c.k" or "fuckyou")
        String fullyCompacted = normalized.replaceAll("\\s+", "");
        for (String badWord : BLACKLIST) {
            if (fullyCompacted.contains(badWord)) {
                return true;
            }
        }

        return false;
    }

    private String normalizeText(String input) {
        StringBuilder sb = new StringBuilder();
        for (char c : input.toLowerCase().toCharArray()) {
            if (LEET_MAP.containsKey(c)) {
                sb.append(LEET_MAP.get(c));
            } else if (Character.isLetterOrDigit(c) || Character.isWhitespace(c)) {
                sb.append(c);
            }
            // Ignore other symbols like *, _, ., etc. to defeat obfuscation attempts
        }
        return sb.toString();
    }
}
