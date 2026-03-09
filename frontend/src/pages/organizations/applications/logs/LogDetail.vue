<script setup lang="ts">
import { onMounted, onUpdated, ref } from 'vue';
import { useRoute } from 'vue-router';

import Hook0CardContentLine from '@/components/Hook0CardContentLine.vue';
import Hook0CardContent from '@/components/Hook0CardContent.vue';
import Hook0CardHeader from '@/components/Hook0CardHeader.vue';
import Hook0Card from '@/components/Hook0Card.vue';
import { UUID } from '@/http';
import Hook0Text from '@/components/Hook0Text.vue';
import * as LogService from './LogService';
import { Response } from './LogService';
import Hook0Code from '@/components/Hook0Code.vue';
import Hook0Loader from '@/components/Hook0Loader.vue';
import Hook0Error from '@/components/Hook0Error.vue';

const route = useRoute();

const response$ = ref<Promise<Response>>();
const response_id = ref<null | UUID>(null);
const application_id = ref<null | UUID>(null);

function _load() {
  if (
    response_id.value !== route.params.response_id ||
    application_id.value !== route.params.application_id
  ) {
    response_id.value = route.params.response_id as UUID;
    application_id.value = route.params.application_id as UUID;

    response$.value = LogService.getResponse(response_id.value, application_id.value);
  }
}

onMounted(() => {
  _load();
});

onUpdated(() => {
  _load();
});

function formatHttpCode(code: number | undefined): string {
  if (code === undefined || code === null) {
    return 'N/A';
  }
  return code.toString();
}

function formatElapsedTime(ms: number | undefined): string {
  if (ms === undefined || ms === null) {
    return 'N/A';
  }
  if (ms < 1000) {
    return `${ms}ms`;
  }
  return `${(ms / 1000).toFixed(2)}s`;
}
</script>

<template>
  <Promised :promise="response$">
    <template #pending>
      <Hook0Loader></Hook0Loader>
    </template>

    <template #rejected="error">
      <Hook0Error :error="error"></Hook0Error>
    </template>

    <template #default="response">
      <div data-test="log-detail-page">
        <Hook0Card data-test="log-detail-card">
          <Hook0CardHeader>
            <template #header> Response Details </template>
            <template #subtitle>
              <Hook0Text class="block">
                <Hook0Text class="label pr-1">Response ID:</Hook0Text>
                <Hook0Text class="code">{{ response.response_id }}</Hook0Text>
              </Hook0Text>

              <Hook0Text class="block">
                <Hook0Text class="label pr-1">HTTP Status:</Hook0Text>
                <Hook0Text
                  class="code"
                  :class="{
                    'text-green-600': response.http_code >= 200 && response.http_code < 300,
                    'text-yellow-600': response.http_code >= 300 && response.http_code < 400,
                    'text-red-600': response.http_code >= 400,
                  }"
                >
                  {{ formatHttpCode(response.http_code) }}
                </Hook0Text>
              </Hook0Text>

              <Hook0Text class="block">
                <Hook0Text class="label pr-1">Elapsed Time:</Hook0Text>
                <Hook0Text class="code">{{
                  formatElapsedTime(response.elapsed_time_ms)
                }}</Hook0Text>
              </Hook0Text>

              <Hook0Text v-if="response.response_error_name" class="block">
                <Hook0Text class="label pr-1">Error:</Hook0Text>
                <Hook0Text class="code text-red-600">{{ response.response_error_name }}</Hook0Text>
              </Hook0Text>
            </template>
          </Hook0CardHeader>
        </Hook0Card>

        <Hook0Card>
          <Hook0CardHeader>
            <template #header>Response Headers</template>
          </Hook0CardHeader>
          <Hook0CardContent>
            <template v-if="response.headers && Object.keys(response.headers).length > 0">
              <Hook0CardContentLine v-for="(value, key) in response.headers" :key="key">
                <template #label>{{ key }}</template>
                <template #content>
                  <Hook0Text class="code">{{ value }}</Hook0Text>
                </template>
              </Hook0CardContentLine>
            </template>
            <template v-else>
              <Hook0CardContentLine>
                <template #label>No headers</template>
              </Hook0CardContentLine>
            </template>
          </Hook0CardContent>
        </Hook0Card>

        <Hook0Card>
          <Hook0CardHeader>
            <template #header>Response Body</template>
          </Hook0CardHeader>
          <Hook0CardContent>
            <Hook0CardContentLine v-if="response.body">
              <template #label>Body</template>
              <template #content>
                <Hook0Code :code="response.body" />
              </template>
            </Hook0CardContentLine>
            <Hook0CardContentLine v-else>
              <template #label>No body</template>
            </Hook0CardContentLine>
          </Hook0CardContent>
        </Hook0Card>
      </div>
    </template>
  </Promised>
</template>
