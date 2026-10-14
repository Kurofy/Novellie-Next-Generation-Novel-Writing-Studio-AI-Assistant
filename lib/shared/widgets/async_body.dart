import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import 'nv_error_state.dart';
import 'nv_skeleton.dart';

class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.isEmpty,
    this.emptyBuilder,
    this.loadingBuilder,
    this.onRetry,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          if (emptyBuilder != null) {
            return emptyBuilder!(context);
          }
        }
        return builder(data);
      },
      error: (error, stackTrace) {
        return NvErrorState(
          title: 'Something went wrong',
          message: error.toString(),
          onRetry: onRetry ?? () {},
        );
      },
      loading: () {
        if (loadingBuilder != null) {
          return loadingBuilder!(context);
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NvSkeleton.rectangular(height: 80),
                SizedBox(height: AppSpacing.md),
                NvSkeleton.rectangular(height: 80),
                SizedBox(height: AppSpacing.md),
                NvSkeleton.rectangular(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}
