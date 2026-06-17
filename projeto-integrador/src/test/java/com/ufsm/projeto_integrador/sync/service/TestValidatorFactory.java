package com.ufsm.projeto_integrador.sync.service;

import jakarta.validation.Validation;
import jakarta.validation.Validator;

final class TestValidatorFactory {

    private static final Validator VALIDATOR = Validation.buildDefaultValidatorFactory().getValidator();

    private TestValidatorFactory() {
    }

    static Validator validator() {
        return VALIDATOR;
    }
}
