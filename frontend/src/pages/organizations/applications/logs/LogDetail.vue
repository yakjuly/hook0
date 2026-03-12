<script setup lang="ts">
import { onMounted, onUpdated, ref } from 'vue';
import { useRoute } from 'vue-router';

import Hook0CardContentLine from '@/components/Hook0CardContentLine.vue';
import Hook0CardContent from '@/components/Hook0CardContent.vue';
import Hook0CardHeader from '@/components/Hook0CardHeader.vue';
import Hook0Card from '@/components/Hook0Card.vue';
import Hook0Button from '@/components/Hook0Button.vue';
import { UUID } from '@/http';
import Hook0Text from '@/components/Hook0Text.vue';
import * as LogService from './LogService';
import { Response, RequestAttemptTypeFixed } from './LogService';
import * as EventsService from '../events/EventsService';
import { EventWithPayload, EventWithPayloadDecoded } from '../events/EventsService';
import Hook0Code from '@/components/Hook0Code.vue';
import Hook0DateTime from '@/components/Hook0DateTime.vue';
import Hook0Loader from '@/components/Hook0Loader.vue';
import Hook0Error from '@/components/Hook0Error.vue';
import { routes } from '@/routes';

const route = useRoute();

const response$ = ref<Promise<Response>>();
const event$ = ref<Promise<EventWithPayload & EventWithPayloadDecoded>>();
const attempt$ = ref<Promise<RequestAttemptTypeFixed | undefined>>();
const response_id = ref<null | UUID>(null);
const event_id = ref<null | UUID>(null);
const application_id = ref<null | UUID>(null);

function _load() {
  if (
    response_id.value !== route.params.response_id ||
    event_id.value !== route.params.event_id ||
    application_id.value !== route.params.application_id
  ) {
    response_id.value = route.params.response_id as UUID;
    event_id.value = route.params.event_id as UUID;
    application_id.value = route.params.application_id as UUID;

    response$.value = LogService.getResponse(response_id.value, application_id.value);
    event$.value = EventsService.get(event_id.value, application_id.value);
    attempt$.value = LogService.listByEventId(application_id.value, event_id.value).then(
      (attempts) => attempts.find((a) => a.response_id === response_id.value)
    );
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
        <Promised :promise="event$">
          <template #pending>
            <Hook0Card>
              <Hook0CardHeader>
                <template #header>Event</template>
              </Hook0CardHeader>
              <Hook0CardContent>
                <Hook0Loader></Hook0Loader>
              </Hook0CardContent>
            </Hook0Card>
          </template>

          <template #rejected="eventError">
            <Hook0Card>
              <Hook0CardHeader>
                <template #header>Event</template>
              </Hook0CardHeader>
              <Hook0CardContent>
                <Hook0Error :error="eventError"></Hook0Error>
              </Hook0CardContent>
            </Hook0Card>
          </template>

          <template #default="event">
            <Hook0Card data-test="log-event-card">
              <Hook0CardHeader>
                <template #header>
                  Event of type
                  <Hook0Text class="code">{{ event.event_type_name }}</Hook0Text>
                </template>
                <template #subtitle>
                  <Hook0Text class="block">
                    <Hook0Text class="label pr-1">Event ID:</Hook0Text>
                    <Hook0Button
                      :to="{
                        name: routes.EventsDetail,
                        params: {
                          organization_id: route.params.organization_id,
                          application_id: route.params.application_id,
                          event_id: event.event_id,
                        },
                      }"
                    >
                      {{ event.event_id }}
                    </Hook0Button>
                  </Hook0Text>
                </template>
              </Hook0CardHeader>
              <Hook0CardContent>
                <Hook0CardContentLine>
                  <template #label>Payload Content Type</template>
                  <template #content>
                    <Hook0Text class="code">{{ event.payload_content_type }}</Hook0Text>
                  </template>
                </Hook0CardContentLine>
                <Hook0CardContentLine>
                  <template #label>Payload (decoded)</template>
                  <template #content>
                    <Hook0Code :code="event.payload_decoded" />
                  </template>
                </Hook0CardContentLine>
              </Hook0CardContent>
            </Hook0Card>
          </template>
        </Promised>

        <Promised :promise="attempt$">
          <template #pending></template>
          <template #rejected></template>
          <template #default="attempt">
            <Hook0Card v-if="attempt" data-test="log-attempt-card">
              <Hook0CardHeader>
                <template #header>Request Attempt</template>
                <template #subtitle>
                  <Hook0Text class="block">
                    <Hook0Text class="label pr-1">Created At:</Hook0Text>
                    <Hook0DateTime :value="attempt.created_at"></Hook0DateTime>
                  </Hook0Text>
                  <Hook0Text class="block">
                    <Hook0Text class="label pr-1">Picked At:</Hook0Text>
                    <Hook0DateTime
                      v-if="attempt.picked_at"
                      :value="attempt.picked_at"
                    ></Hook0DateTime>
                    <Hook0Text v-else class="code">pending…</Hook0Text>
                  </Hook0Text>
                </template>
              </Hook0CardHeader>
            </Hook0Card>
          </template>
        </Promised>

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
            <div
              v-if="response.headers && Object.keys(response.headers).length > 0"
              class="headers-list"
            >
              <div v-for="(value, key) in response.headers" :key="key" class="header-row">
                <Hook0Text class="label header-key">{{ key }}</Hook0Text>
                <Hook0Text class="header-value">{{ value }}</Hook0Text>
              </div>
            </div>
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

<style lang="scss" scoped>
.headers-list {
  @apply px-4 py-2 sm:px-6;
}

.header-row {
  @apply py-1 sm:grid sm:grid-cols-3 sm:gap-4;
}

.header-key {
  @apply text-sm;
}

.header-value {
  @apply font-mono font-medium text-sm select-text cursor-text break-all;
}
</style>
