package br.edu.ifpe.rededor.exception;

public class CustomException extends Exception {
    public CustomException(String errorMessage){
        super(errorMessage);
    }

    public CustomException(String errorMessage, Throwable error){
        super(errorMessage, error);
    }

}
