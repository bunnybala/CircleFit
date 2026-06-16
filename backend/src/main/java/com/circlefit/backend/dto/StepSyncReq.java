package com.circlefit.backend.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class StepSyncReq {
    private LocalDate date;
    private Integer steps;
    private Double distance;
    private Double calories;
}
