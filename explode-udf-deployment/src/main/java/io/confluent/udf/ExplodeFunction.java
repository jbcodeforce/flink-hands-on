package io.confluent.udf;

import org.apache.flink.table.annotation.DataTypeHint;
import org.apache.flink.table.annotation.FunctionHint;
import org.apache.flink.table.functions.TableFunction;
import org.apache.flink.types.Row;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Deque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayDeque;

/**
 * A Table Function that explodes a list of strings into a list of rows
 * Input: list of strings
 * Output: Emits one row per string in the list
 */
@FunctionHint(output = @DataTypeHint("ROW<sub_string STRING>"))
public class ExplodeFunction extends TableFunction {
    private static final Logger logger = LogManager.getLogger();


    public void eval(List<String> strList) throws Exception {
        logger.info("Starting exploding: {}", strList);
        if (strList == null) {
            return;
        }
        
        for (String subStr : strList) {
            collect(Row.of(subStr));
        }
    }

    /**
     * Returns a string describing the function.
     */
    @Override
    public String toString() {
        return "EXPLODE";
    }

}

