package com.learnflow.domain.user;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Optional;

@Mapper
public interface UserMapper {

    Optional<User> findByIdAndTenant(@Param("id") Long id, @Param("tenantId") String tenantId);

    Optional<User> findByEmailAndTenant(@Param("email") String email, @Param("tenantId") String tenantId);
}
