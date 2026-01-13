package io.confluent.udf;

import org.apache.flink.types.Row;
import org.apache.flink.util.Collector;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ExplodeFunctionTest {
    private ExplodeFunction function;
    private List<Row> collectedRows;

    /**
     * A simple Collector implementation that stores collected rows in a list.
     */
    private static class ListCollector implements Collector<Row> {
        private final List<Row> rows;

        ListCollector(List<Row> rows) {
            this.rows = rows;
        }

        @Override
        public void collect(Row row) {
            rows.add(row);
        }

        @Override
        public void close() {
            // No-op
        }
    }

    @BeforeEach
    void setUp() throws Exception {
        function = new ExplodeFunction();
        collectedRows = new ArrayList<>();

        // Inject the collector using reflection
        Field collectorField = function.getClass().getSuperclass().getDeclaredField("collector");
        collectorField.setAccessible(true);
        collectorField.set(function, new ListCollector(collectedRows));
    }

    @Test
    void testExplodeToArray() throws Exception {
        // Create rows with structure: (group_name, item_name, item_type)
        List<String> strList = new ArrayList<>(Arrays.asList("string1", "string2", "string3"));
        function.eval(strList);    
        assertEquals(3, collectedRows.size(), "Should find 3");
        collectedRows.forEach(System.out::println);
    }

    @Test
    void testToString() {
        assertEquals("EXPLODE", function.toString());
    }

}
