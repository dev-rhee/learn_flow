package com.learnflow.global.interceptor;

import lombok.extern.slf4j.Slf4j;
import net.sf.jsqlparser.JSQLParserException;
import net.sf.jsqlparser.expression.Expression;
import net.sf.jsqlparser.expression.operators.conditional.AndExpression;
import net.sf.jsqlparser.parser.CCJSqlParserUtil;
import net.sf.jsqlparser.statement.select.PlainSelect;
import net.sf.jsqlparser.statement.select.Select;
import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.mapping.ParameterMapping;
import org.apache.ibatis.mapping.SqlSource;
import org.apache.ibatis.plugin.*;
import org.apache.ibatis.session.ResultHandler;
import org.apache.ibatis.session.RowBounds;
import org.springframework.stereotype.Component;

import java.lang.reflect.Field;
import java.util.Properties;

@Slf4j
@Component
@Intercepts({
    @Signature(
        type = Executor.class,
        method = "query",
        args = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class}
    )
})
public class TenantInterceptor implements Interceptor {

    // 테넌트 격리가 필요 없는 테이블 (공유 마스터 데이터)
    private static final java.util.Set<String> SKIP_TABLES = java.util.Set.of(
        "role", "permission", "role_permission", "tenant"
    );

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        String tenantId = TenantContext.getTenantId();

        if (tenantId == null) {
            return invocation.proceed();
        }

        MappedStatement ms = (MappedStatement) invocation.getArgs()[0];
        Object parameter   = invocation.getArgs()[1];
        BoundSql boundSql  = ms.getBoundSql(parameter);

        String originalSql = boundSql.getSql().trim();

        if (shouldSkip(originalSql)) {
            return invocation.proceed();
        }

        if (originalSql.toLowerCase().contains("tenant_id")) {
            return invocation.proceed();
        }

        String injectedSql = injectTenantFilter(originalSql, tenantId);
        log.debug("[TenantInterceptor] tenant={} | {}", tenantId, injectedSql);

        BoundSql newBoundSql = new BoundSql(
            ms.getConfiguration(),
            injectedSql,
            boundSql.getParameterMappings(),
            boundSql.getParameterObject()
        );

        copyAdditionalParameters(boundSql, newBoundSql);

        MappedStatement newMs = copyMappedStatement(ms, new InjectedSqlSource(newBoundSql));
        invocation.getArgs()[0] = newMs;

        return invocation.proceed();
    }

    private boolean shouldSkip(String sql) {
        String lower = sql.toLowerCase();
        return SKIP_TABLES.stream().anyMatch(t -> lower.contains("from " + t));
    }

    private String injectTenantFilter(String sql, String tenantId) throws JSQLParserException {

        Select select = (Select) CCJSqlParserUtil.parse(sql);

        PlainSelect plainSelect =
                (PlainSelect) select.getSelectBody();

        Expression tenantExpr =
                CCJSqlParserUtil.parseCondExpression(
                        "tenant_id = '" + tenantId + "'"
                );

        if (plainSelect.getWhere() == null) {

            plainSelect.setWhere(tenantExpr);

        } else {

            plainSelect.setWhere(
                    new AndExpression(
                            plainSelect.getWhere(),
                            tenantExpr
                    )
            );
        }

        return plainSelect.toString();
    }

    private void copyAdditionalParameters(BoundSql source, BoundSql target) {
        try {
            Field additionalField = BoundSql.class.getDeclaredField("additionalParameters");
            additionalField.setAccessible(true);
            @SuppressWarnings("unchecked")
            java.util.Map<String, Object> additional =
                (java.util.Map<String, Object>) additionalField.get(source);
            additional.forEach(target::setAdditionalParameter);
        } catch (Exception e) {
            log.warn("[TenantInterceptor] additionalParameters 복사 실패", e);
        }
    }

    private MappedStatement copyMappedStatement(MappedStatement ms, SqlSource sqlSource) {
        MappedStatement.Builder builder = new MappedStatement.Builder(
            ms.getConfiguration(), ms.getId(), sqlSource, ms.getSqlCommandType()
        );
        builder.resource(ms.getResource())
               .fetchSize(ms.getFetchSize())
               .statementType(ms.getStatementType())
               .keyGenerator(ms.getKeyGenerator())
               .timeout(ms.getTimeout())
               .parameterMap(ms.getParameterMap())
               .resultMaps(ms.getResultMaps())
               .resultSetType(ms.getResultSetType())
               .cache(ms.getCache())
               .flushCacheRequired(ms.isFlushCacheRequired())
               .useCache(ms.isUseCache());
        return builder.build();
    }

    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }

    @Override
    public void setProperties(Properties properties) {}

    private record InjectedSqlSource(BoundSql boundSql) implements SqlSource {
        @Override
        public BoundSql getBoundSql(Object parameterObject) {
            return boundSql;
        }
    }
}
