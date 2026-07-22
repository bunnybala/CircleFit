package com.circlefit.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WaterLogDto {
    private LocalDate date;
    private Integer amountMl;
    private Integer goalMl;
}
